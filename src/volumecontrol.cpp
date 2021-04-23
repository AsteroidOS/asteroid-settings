/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Based on a code from lipstick under the following license.
 *
 * Copyright (C) 2012 Jolla Ltd.
 * Contact: Robin Burchell <robin.burchell@jollamobile.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 * and appearing in the file LICENSE.LGPL included in the packaging
 * of this file.
 */

#include "volumecontrol.h"
#include <QDBusMessage>
#include <QDBusConnection>
#include <QDBusArgument>
#include <dbus/dbus-glib-lowlevel.h>
#include <QTimer>
#include <QDebug>

#define DBUS_ERR_CHECK(err) \
    if (dbus_error_is_set(&err)) \
    { \
        qWarning() << err.message; \
        dbus_error_free(&err); \
    }

static const char *VOLUME_SERVICE = "com.Meego.MainVolume2";
static const char *VOLUME_PATH = "/com/meego/mainvolume2";
static const char *VOLUME_INTERFACE = "com.Meego.MainVolume2";

VolumeControl::VolumeControl(QObject *parent) :
    QObject(parent),
    dbusConnection(NULL),
    volumePercentage(0),
    maximumVolume(0),
    effect(NULL),
    reconnectTimeout(2000) // first reconnect after 2000ms
{
    update();
}

VolumeControl::~VolumeControl()
{
    if (dbusConnection != NULL) {
        dbus_connection_remove_filter(dbusConnection, VolumeControl::signalHandler, (void *)this);
        dbus_connection_unref(dbusConnection);
    }
}

void VolumeControl::openConnection()
{
    //! If the connection already exists, do nothing
    if ((dbusConnection != NULL) && (dbus_connection_get_is_connected(dbusConnection))) {
        return;
    }

    // Establish a connection to the server
    char *pa_bus_address = getenv("PULSE_DBUS_SERVER");
    QByteArray addressArray;
    if (pa_bus_address == NULL) {
        QDBusMessage message = QDBusMessage::createMethodCall("org.pulseaudio.Server", "/org/pulseaudio/server_lookup1",
                                                              "org.freedesktop.DBus.Properties", "Get");
        message.setArguments(QVariantList() << "org.PulseAudio.ServerLookup1" << "Address");
        QDBusMessage reply = QDBusConnection::sessionBus().call(message);
        if (reply.type() == QDBusMessage::ReplyMessage && reply.arguments().count() > 0) {
            addressArray = reply.arguments().first().value<QDBusVariant>().variant().toString().toLatin1();
            pa_bus_address = addressArray.data();
        }
    }

    if (pa_bus_address != NULL) {
        DBusError dbus_err;
        dbus_error_init(&dbus_err);

        dbusConnection = dbus_connection_open(pa_bus_address, &dbus_err);

        DBUS_ERR_CHECK(dbus_err);
    }

    if (dbusConnection != NULL) {
        dbus_connection_setup_with_g_main(dbusConnection, NULL);
        dbus_connection_add_filter(dbusConnection, VolumeControl::signalHandler, (void *)this, NULL);

        addSignalMatch();
    }

    if (!dbusConnection) {
        QTimer::singleShot(reconnectTimeout, this, SLOT(update()));
        reconnectTimeout += 5000; // next reconnects wait for 5000ms more
    }
}

void VolumeControl::update()
{
    openConnection();

    if (dbusConnection == NULL) {
        return;
    }

    DBusError error;
    dbus_error_init(&error);

    DBusMessage *reply = NULL;
    DBusMessage *msg = dbus_message_new_method_call(VOLUME_SERVICE, VOLUME_PATH, "org.freedesktop.DBus.Properties", "GetAll");
    if (msg != NULL) {
        dbus_message_append_args(msg, DBUS_TYPE_STRING, &VOLUME_INTERFACE, DBUS_TYPE_INVALID);

        reply = dbus_connection_send_with_reply_and_block(dbusConnection, msg, -1, &error);

        DBUS_ERR_CHECK (error);

        dbus_message_unref(msg);
    }

    int currentStep = -1, stepCount = -1;

    if (reply != NULL) {
        if (dbus_message_get_type(reply) == DBUS_MESSAGE_TYPE_METHOD_RETURN) {
            DBusMessageIter iter;
            dbus_message_iter_init(reply, &iter);
            // Recurse into the array [array of dicts]
            while (dbus_message_iter_get_arg_type(&iter) != DBUS_TYPE_INVALID) {
                DBusMessageIter dict_entry;
                dbus_message_iter_recurse(&iter, &dict_entry);

                // Recurse into the dict [ dict_entry (string, variant) ]
                while (dbus_message_iter_get_arg_type(&dict_entry) != DBUS_TYPE_INVALID) {
                    DBusMessageIter in_dict;
                    // Recurse into the dict_entry [ string, variant ]
                    dbus_message_iter_recurse(&dict_entry, &in_dict);
                    {
                        const char *prop_name = NULL;
                        // Get the string value, "property name"
                        dbus_message_iter_get_basic(&in_dict, &prop_name);

                        dbus_message_iter_next(&in_dict);

                        DBusMessageIter variant;
                        // Recurse into the variant [ variant ]
                        dbus_message_iter_recurse(&in_dict, &variant);

                        if (prop_name == NULL) {
                        } else if (dbus_message_iter_get_arg_type(&variant) == DBUS_TYPE_UINT32) {
                            quint32 value;
                            dbus_message_iter_get_basic(&variant, &value);

                            if (strcmp(prop_name, "StepCount") == 0) {
                                stepCount = value;
                            } else if (strcmp(prop_name, "CurrentStep") == 0) {
                                currentStep = value;
                            } 
                        }
                    }

                    dbus_message_iter_next(&dict_entry);
                }
                dbus_message_iter_next(&iter);
            }
        }
        dbus_message_unref(reply);
    }

    if (currentStep != -1 && stepCount != -1) {
        setSteps(currentStep, stepCount);
    }
}

void VolumeControl::addSignalMatch()
{
    DBusMessage *message = dbus_message_new_method_call(NULL, "/org/pulseaudio/core1", NULL, "ListenForSignal");
    if (message != NULL) {
        const char *signalPtr = "com.Meego.MainVolume2.StepsUpdated";
        char **emptyarray = { NULL };
        dbus_message_append_args(message, DBUS_TYPE_STRING, &signalPtr, DBUS_TYPE_ARRAY, DBUS_TYPE_OBJECT_PATH,
                                 &emptyarray, 0, DBUS_TYPE_INVALID);
        dbus_connection_send(dbusConnection, message, NULL);
        dbus_message_unref(message);
    }
}

DBusHandlerResult VolumeControl::signalHandler(DBusConnection *, DBusMessage *message, void *control)
{
    if (!message)
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;

    DBusError error;
    dbus_error_init(&error);

    if (dbus_message_has_member(message, "StepsUpdated")) {
        quint32 currentStep = 0;
        quint32 stepCount = 0;

        if (dbus_message_get_args(message, &error, DBUS_TYPE_UINT32, &stepCount, DBUS_TYPE_UINT32, &currentStep, DBUS_TYPE_INVALID)) {
            static_cast<VolumeControl*>(control)->setSteps(currentStep, stepCount);
        }
    }

    DBUS_ERR_CHECK (error);
    return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}

void VolumeControl::setSteps(quint32 volume, quint32 stepCount)
{
    // The pulseaudio API reports the step count (starting from 0), so the maximum volume is stepCount - 1
    maximumVolume = stepCount-1;
    quint32 clampedVolume = qMin(volume, maximumVolume);
    int newVolumePercentage = 100*(float)clampedVolume/(float)(maximumVolume);

    if (volumePercentage != newVolumePercentage) {
        volumePercentage = newVolumePercentage;
        emit volumeChanged();
    }
}

void VolumeControl::setVolume(int volume)
{
    int newVolumePercentage = qBound(0, volume, 100);
    int newVolume = (maximumVolume)*(float)newVolumePercentage/(float)100;

    if (newVolumePercentage != volumePercentage) {
        volumePercentage = newVolumePercentage;
        // Check the connection, maybe PulseAudio restarted meanwhile
        openConnection();

        // Don't try to set the volume via D-bus when it isn't available
        if (dbusConnection == NULL) {
            return;
        }

        DBusMessage *message = dbus_message_new_method_call(VOLUME_SERVICE, VOLUME_PATH, "org.freedesktop.DBus.Properties", "Set");
        if (message != NULL) {
            static const char *method = "CurrentStep";
            if (dbus_message_append_args(message, DBUS_TYPE_STRING, &VOLUME_INTERFACE, DBUS_TYPE_STRING, &method, DBUS_TYPE_INVALID)) {
                DBusMessageIter append;
                DBusMessageIter sub;

                // Create and append the variant argument ...
                dbus_message_iter_init_append(message, &append);

                dbus_message_iter_open_container(&append, DBUS_TYPE_VARIANT, DBUS_TYPE_UINT32_AS_STRING, &sub);
                // Set the variant argument value:
                dbus_message_iter_append_basic(&sub, DBUS_TYPE_UINT32, &newVolume);
                // Close the append iterator
                dbus_message_iter_close_container(&append, &sub);

                // Send/flush the message immediately:
                dbus_connection_send(dbusConnection, message, NULL);
            }

            dbus_message_unref(message);
        }
        emit volumeChanged();
        if(effect != NULL)
            effect->stop();
        effect = new QMediaPlayer(this);
        effect->setMedia(QUrl::fromLocalFile("/usr/share/sounds/notification.wav"));
        effect->play();
    }
}

int VolumeControl::volume()
{
    return volumePercentage;
}

